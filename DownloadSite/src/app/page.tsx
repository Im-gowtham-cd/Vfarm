import HomeStyle from './page.module.css'
import Image from 'next/image'
import i1 from '../../assests/images/H1.png'

export default function App() {

    const navLinks = ['Home', 'About', 'Features', 'How it works ?']

    const stats = [
        '1 K+ Downloads', '500+ Users', 'Secure', 'Trusted', '24/7 Support',
        'Easy to Use', 'Reliable', 'Cloud Based', 'Affordable', 'Verified'
    ]

    const aboutList = [
        "VFarm is a next-generation agri-tech platform redefining how farmers access knowledge, resources, and opportunities. We leverage technology, data, and AI to transform everyday farming into a smarter, more profitable, and more sustainable practice.",
        "Built for the real needs of farmers, VFarm delivers powerful tools in a simple mobile experience — from government scheme access and real-time weather insights to market intelligence and AI-driven farming recommendations. Everything a farmer needs, unified in one digital ecosystem.",
        "Our vision is to digitize agriculture at the grassroots level, ensuring that even small and medium farmers can benefit from modern innovation. With multilingual support and farmer-friendly design, VFarm makes advanced technology truly accessible.",
        "We are not just supporting farmers — we are enabling a future where agriculture is data-driven, connected, and resilient."
    ]

    const features = [
        { t: 'Smarter Decisions', d: 'AI-powered insights that guide every step of your farming journey.' },
        { t: 'Effortless Access', d: 'Government schemes and services, simplified in one place.' },
        { t: 'Know the Weather', d: 'Real-time forecasts to protect what you grow.' },
        { t: 'Sell Smarter', d: 'Live market prices that help you maximize value.' },
        { t: 'All Documents. One Place.', d: 'Secure, digital, always within reach.' },
        { t: 'Stronger Together', d: 'A community that grows knowledge and success.' },
        { t: 'Expert Help', d: 'Trusted advice, when it matters most.' },
        { t: 'Track Progress', d: 'Every activity logged. Every improvement measured.' },
        { t: 'Private & Secure', d: 'Your data stays yours — protected by design.' }
    ]

    return (
        <div className={HomeStyle.HomeCenter}>

            <nav className={HomeStyle.nav}>
                <h1>V Farm</h1>
                <ul>
                    {navLinks.map((link, i) => (
                        <a key={i} href="">{link}</a>
                    ))}
                </ul>
                <a href="">Download <i className="bx bx-arrow-to-bottom" /></a>
            </nav>

            <div className={HomeStyle.HomeContainer}>
                <section className={HomeStyle.Home}>
                    <div className={HomeStyle.HomeContext}>
                        <p>We Farm , We Evolve</p>
                        <p>
                            V Farm makes farming simple with easy tools and instant access to schemes,
                            weather, and expert advice. Fast, secure, and built to support every farmer’s success.
                        </p>
                        <ul>
                            <a href="">Explore <i className="bx bx-arrow-in-up-right-circle" /></a>
                        </ul>
                    </div>

                    <div className={HomeStyle.HomeImage}>
                        <div className={HomeStyle.HomeCaro}>
                            <div className={HomeStyle.Card}>
                                <Image src={i1} alt="Farm illustration" className={HomeStyle.img} />
                                <ul>
                                    <p>Commuinty Chat</p>
                                    <p>The community based feature that helps to communicate the other farmer.</p>
                                    <span>
                                        <button>Next <i className="bx bx-arrow-in-up-right-circle" /></button>
                                    </span>
                                </ul>
                            </div>
                        </div>
                    </div>
                </section>

                <div className={HomeStyle.HomeDownload}>
                    <div className={HomeStyle.Carosel}>
                        {stats.map((s, i) => <p key={i}>{s}</p>)}
                    </div>
                    <div className={HomeStyle.Carosel} aria-hidden>
                        {stats.map((s, i) => <p key={i}>{s}</p>)}
                    </div>
                </div>
            </div>

            <section className={HomeStyle.AboutContainer}>
                <p className={HomeStyle.AboutApplication}>About -- V Farm</p>
                <ul className={HomeStyle.AboutContext}>
                    {aboutList.map((text, i) => (
                        <li key={i}>{i + 1} ) {text}</li>
                    ))}
                </ul>
                <div className={HomeStyle.DownloadButtonContainer}>
                    <button>Download <i className="bx bx-arrow-to-bottom" /></button>
                    <button>Versions <i className="bx bx-layers-down-right" /></button>
                </div>
            </section>

            <section className={HomeStyle.FeatureContainer}>
                <p className={HomeStyle.FeatureText}>Features</p>
                <div className={HomeStyle.FeatureCardContainer}>
                    {features.map((f, i) => (
                        <div key={i} className={HomeStyle.FeatureCard}>
                            <p>{f.t}</p>
                            <p>{f.d}</p>
                        </div>
                    ))}
                </div>
            </section>

            {/* <section className={HomeStyle.VersionContainer}>
                    <p>Version</p>
            </section> */}

        </div>
    )
}
