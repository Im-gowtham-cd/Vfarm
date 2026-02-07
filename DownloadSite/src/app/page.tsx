import HomeStyle from './page.module.css'
import Image from 'next/image'
import i1 from '../../assests/images/H1.png'

export default function App() {
    return (
        <>
            <nav className={HomeStyle.nav}>
                <h1>V Farm</h1>
                <ul>
                    <a href="">Home</a>
                    <a href="">Features</a>
                    <a href="">About</a>
                    <a href="">How it works ?</a>
                </ul>
                <a href="">Download <i className="bx bx-arrow-to-bottom" /></a>
            </nav>
            <div className={HomeStyle.HomeContainer}>

                <section className={HomeStyle.Home}>
                    <div className={HomeStyle.HomeContext}>
                        <p>We Farm , We Evolve</p>
                        <p>V Farm makes farming simple with easy tools and instant access to schemes, weather, and expert advice.
                            Fast, secure, and built to support every farmer’s success.</p>
                        <ul>
                            <a href="">Explore <i className="bx bx-arrow-in-up-right-circle" /> </a>
                        </ul>
                    </div>
                    <div className={HomeStyle.HomeImage}>
                        <div className={HomeStyle.HomeCaro}>
                            <div className={HomeStyle.Card}>
                                <Image src={i1} alt="Farm illustration" className={HomeStyle.img} />
                                <ul>
                                    <p>Commuinty Chat</p>
                                    <p>The community based feature that helps to communicate the other farmer.</p>
                                    <span><button>Next <i className="bx bx-arrow-in-up-right-circle" /> </button></span>
                                </ul>
                            </div>
                        </div>
                    </div>
                </section>
                <div className={HomeStyle.HomeDownload}>
                    <div className={HomeStyle.Carosel}>
                        <p>1 K+ Downloads</p>
                        <p>500+ Users</p>
                        <p>Secure</p>
                        <p>Trusted</p>
                        <p>24/7 Support</p>
                        <p>Easy to Use</p>
                        <p>Reliable</p>
                        <p>Cloud Based</p>
                        <p>Affordable</p>
                        <p>Verified</p>
                    </div>
                    <div className={HomeStyle.Carosel} aria-hidden>
                        <p>1 K+ Downloads</p>
                        <p>500+ Users</p>
                        <p>Secure</p>
                        <p>Trusted</p>
                        <p>24/7 Support</p>
                        <p>Easy to Use</p>
                        <p>Reliable</p>
                        <p>Cloud Based</p>
                        <p>Affordable</p>
                        <p>Verified</p>
                    </div>
                </div>
            </div>
            <section className={HomeStyle.DownloadContainer}>
                <div>
                    <button>Download <i className="bx bx-arrow-to-bottom" /></button>
                    <button>Versions <i className="bx bx-layers-down-right" /></button>
                </div>
            </section>
        </>
    )
}